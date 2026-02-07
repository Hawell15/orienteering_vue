<template>
    <table class="table table-striped table-bordered table-hover">
        <thead class="table-primary">
            <tr>
                <td @click="orderTable('id')">FOS ID</td>
                <td @click="orderTable('full_name')">Nume</td>
                <td @click="orderTable('category_id')">Categoria actuală</td>
                <td @click="orderTable('category_valid')">Valabilitate</td>
                <td @click="orderTable('gender')">Genul</td>
                <td @click="orderTable('yob')">Anul Nașterii</td>
                <td @click="orderTable('club_name')">Club</td>
                <td @click="orderTable('best_category_id')">Titlul Sportiv</td>
                <td @click="orderTable('wre_id')">WRE ID</td>
                <td @click="orderTable('sprint_wre_place')">Sprint WRE</td>
                <td @click="orderTable('forest_wre_place')">Padure WRE</td>
                <th colspan="3">Actiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in elements" :key="element.id">
                <td><a :href="`/runners/${element.id}`">{{element.id}}</a></td>
                <td><a :href="`/runners/${element.id}`">{{element.full_name}}</a></td>
                <td><a :href="`/categories/${element.category_id}`">{{element.category_name}}</a></td>
                <td>{{element.category_valid}}</td>
                <td>{{element.gender}}</td>
                <td>{{element.yob}}</td>
                <td><a :href="`/clubs/${element.club_id}`">{{element.club_name}}</a></td>
                <td><a :href="`/categories/${element.best_category_id}`">{{element.best_category_name}}</a></td>
                <td>{{element.wre_id}}</td>
                <td>
                    <p v-if="element.sprint_wre_place">{{element.sprint_wre_place}}/{{element.sprint_wre_rang}}</p>
                </td>
                <td>
                    <p v-if="element.forest_wre_place">{{element.forest_wre_place}}/{{element.forest_wre_rang}}</p>
                </td>
                <td><a class="btn btn-sm btn-warning" :href="`/runners/${element.id}`">Arată</a></td>
                <td><button class="btn btn-sm btn-success" @click="editElement(element)">Editează</button></td>
                <td><button class="btn btn-sm btn-danger" @click="deleteElement(element.id)">Șterge</button></td>
            </tr>
        </tbody>
    </table>
    <Modal ref="modal" :runner="modalElement" :isNew="false" @save="updateElement" />
</template>
<script setup>
import { ref } from 'vue'
import axios from 'axios'
import Modal from './Modal.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

const props = defineProps({
    elements: Object
})

const emit = defineEmits(['order'])

const modalElement = ref({})
const modal = ref(null)

function deleteElement(id) {
    if (confirm('Esti sigur ca vrei sa stergi aceast sportiv?')) {
        axios.delete(`/runners/${id}`).then(() => {
            props.elements = props.elements.filter(runner => runner.id !== id)
        })
    }
}

function editElement(element) {
    modalElement.value = { ...element }
    modal.value.show()
}

function updateElement(elementData, done) {
    axios.patch(`/runners/${elementData.id}.json`, { runner: elementData }).then(res => {
        const index = props.elements.findIndex(c => c.id === res.data.id)
        if (index !== -1) props.elements[index] = { ...props.elements[index], ...res.data }
        done()
    })
}

function orderTable(sortKey) {
    emit('order', sortKey)
}
</script>
