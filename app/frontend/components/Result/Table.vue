<template>
    <table class="table table-striped table-bordered table-hover">
        <thead class="table-primary">
            <tr>
                <td @click="orderTable('place')">Locul</td>
                <td @click="orderTable('full_name')">Sportiv</td>
                <td @click="orderTable('club_name')">Club</td>
                <td @click="orderTable('runner_category_name')">Categoria actuala</td>
                <td @click="orderTable('time')">Timpul</td>
                <td @click="orderTable('result_category_name')">Categoria Indeplinita</td>
                <td @click="orderTable('status')">Indeplinire</td>
                <td @click="orderTable('date')">Data</td>
                <td @click="orderTable('competition_name')">Competitia</td>
                <td @click="orderTable('group_name')">Grupa</td>
                <td @click="orderTable('wre_points')">WRE Puncte</td>
                <td @click="orderTable('ecn_points')">ECN Puncte</td>
                <th colspan="3">Actiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in elements" :key="element.id">
                <td>{{element.place}}</td>
                <td><a :href="`runners/${element.runner_id}`">{{element.full_name}}</a></td>
                <td><a :href="`clubs/${element.club_id}`">{{element.club_name}}</a></td>
                <td><a :href="`categories/${element.runner_category_id}`">{{element.runner_category_name}}</a></td>
                <td>{{formatResultTime(element.time)}}</td>
                <td><a :href="`categories/${element.result_category_id}`">{{element.result_category_name}}</a></td>
                <td>{{element.status}}</td>
                <td>{{element.date}}</td>
                <td><a :href="`competitions/${element.competition_id}`">{{element.competition_name}}</a></td>
                <td><a :href="`groups/${element.group_id}`">{{element.group_name}}</a></td>
                <td>{{element.wre_points}}</td>
                <td>{{element.ecn_points}}</td>
                <td><a class="btn btn-sm btn-warning" :href="`results/${element.id}`">Arată</a></td>
                <td><button class="btn btn-sm btn-success" @click="editElement(element)">Editează</button></td>
                <td><button class="btn btn-sm btn-danger" @click="deleteElement(element.id)">Șterge</button></td>
            </tr>
        </tbody>
    </table>
    <Modal ref="modal" :result="modalElement" :isNew="false" @save="updateElement" />
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
    if (confirm('Esti sigur ca vrei sa stergi aceast rezultat?')) {
        axios.delete(`/results/${id}`).then(() => {
            props.elements = props.elements.filter(result => result.id !== id)
        })
    }
}

function editElement(element) {
    modalElement.value = {
        ...element,
        time: formatResultTime(element.time)
    }
    modal.value.show()
}

function updateElement(elementData, done) {
    axios.patch(`/results/${elementData.id}.json`, { result: elementData }).then(res => {
        const index = props.elements.findIndex(c => c.id === res.data.id)
        if (index !== -1) props.elements[index] = { ...props.elements[index], ...res.data }
        done()
    })
}

function orderTable(sortKey) {
    emit('order', sortKey)
}

function formatResultTime(seconds) {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;

    return (
        String(h).padStart(2, '0') + ':' +
        String(m).padStart(2, '0') + ':' +
        String(s).padStart(2, '0')
    );
}

</script>
