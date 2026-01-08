<template>
    <div class="mt-4 p-5 bg-light text-black rounded --bs-gray-500">
        <h1> {{category.full_name}}</h1>
        <p><strong>Denumirea: </strong>{{category.category_name}}</p>
        <hr class="my-4">
        <p><strong>Puncte: </strong>{{category.points}}</p>
        <p><strong>Validitate: </strong>{{category.validaty_period}} ani</p>
        <p><strong>Numarul de sportivi: </strong><a :href="`/runners?category=${category.id}`">{{runners.length}}</a></p>
        <p><strong>Numarul de rezultate: </strong><a :href="`/results?category=${category.id}`">{{results.length}}</a></p>
    </div>
    <p class="d-inline-flex gap-1">
        <a class="btn btn-primary" data-bs-toggle="collapse" href="#runnersTable" role="button" aria-expanded="false" aria-controls="runnersTable">
            Sportivi
        </a>
    </p>
    <div class="collapse" id="runnersTable">
        <div class="card card-body">
            <table class="table table-striped table-bordered table-hover">
                <thead class="table-primary">
                    <tr>
                        <td @click="orderRunnerTable('id')">FOS ID</td>
                        <td @click="orderRunnerTable('full_name')">Nume</td>
                        <td @click="orderRunnerTable('category_id')">Categoria actuală</td>
                        <td @click="orderRunnerTable('category_valid')">Valabilitate</td>
                        <td @click="orderRunnerTable('gender')">Genul</td>
                        <td @click="orderRunnerTable('yob')">Anul Nașterii</td>
                        <td @click="orderRunnerTable('club_name')">Club</td>
                        <td @click="orderRunnerTable('best_category_id')">Titlul Sportiv</td>
                        <td @click="orderRunnerTable('wre_id')">WRE ID</td>
                        <td @click="orderRunnerTable('sprint_wre_place')">Sprint WRE</td>
                        <td @click="orderRunnerTable('forest_wre_place')">Padure WRE</td>
                        <th colspan="3">Actiuni</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="element in runners" :key="element.id">
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
                        <td>
                            <a class="btn btn-sm btn-warning" :href="`/runners/${element.id}`">
                                Arată
                            </a>
                        </td>
                        <td>
                            <button class="btn btn-sm btn-success" @click="editElement(element)">
                                Editează
                            </button>
                        </td>
                        <td>
                            <button class="btn btn-sm btn-danger" @click="deleteElement(element.id)">
                                Șterge
                            </button>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
    <br>
    <p class="d-inline-flex gap-1">
        <a class="btn btn-primary" data-bs-toggle="collapse" href="#resultsTable" role="button" aria-expanded="false" aria-controls="resultsTable">
            Rezultate
        </a>
    </p>
    <div class="collapse" id="resultsTable">
        <div class="card card-body">
            <table class="table table-striped table-bordered table-hover">
                <thead class="table-primary">
                    <tr>
                        <td @click="orderResultTable('place')">Locul</td>
                        <td @click="orderResultTable('full_name')">Sportiv</td>
                        <td @click="orderResultTable('club_name')">Club</td>
                        <td @click="orderResultTable('runner_category_name')">Categoria actuala</td>
                        <td @click="orderResultTable('time')">Timpul</td>
                        <td @click="orderResultTable('result_category_name')">Categoria Indeplinita</td>
                        <td @click="orderResultTable('status')">Indeplinire</td>
                        <td @click="orderResultTable('date')">Data</td>
                        <td @click="orderResultTable('competition_name')">Competitia</td>
                        <td @click="orderResultTable('group_name')">Grupa</td>
                        <td @click="orderResultTable('wre_points')">WRE Puncte</td>
                        <td @click="orderResultTable('ecn_points')">ECN Puncte</td>
                        <th colspan="3">Actiuni</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="element in results" :key="element.id">
                        <td>{{element.place}}</td>
                        <td><a :href="`/runners/${element.runner_id}`">{{element.full_name}}</a></td>
                        <td><a :href="`/clubs/${element.club_id}`">{{element.club_name}}</a></td>
                        <td><a :href="`/categories/${element.runner_category_id}`">{{element.runner_category_name}}</a></td>
                        <td>{{formatResultTime(element.time)}}</td>
                        <td><a :href="`/categories/${element.result_category_id}`">{{element.result_category_name}}</a></td>
                        <td>{{element.status}}</td>
                        <td>{{element.date}}</td>
                        <td><a :href="`/competitions/${element.competition_id}`">{{element.competition_name}}</a></td>
                        <td><a :href="`/groups/${element.group_id}`">{{element.group_name}}</a></td>
                        <td>{{element.wre_points}}</td>
                        <td>{{element.ecn_points}}</td>
                        <td>
                            <a class="btn btn-sm btn-warning" :href="`/results/${element.id}`">
                                Arată
                            </a>
                        </td>
                        <td>
                            <button class="btn btn-sm btn-success" @click="editElement(element)">
                                Editează
                            </button>
                        </td>
                        <td>
                            <button class="btn btn-sm btn-danger" @click="deleteElement(element.id)">
                                Șterge
                            </button>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
    <p class="lead">
        <button class="btn btn-sm btn-success" @click="editCategory(category)">Editeaza</button>
        <button class="btn btn-danger btn-sm" @click="deleteCategory(category.id)">Sterge</button>
    </p>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'

const category = ref({})
const runners = ref([])
const results = ref([])
const categoryId = ref("")
const runnerSorting = ref({
    "sorting[sort_by]": "id",
    "sorting[direction]": "asc"
})

const resultSorting = ref({
    "sorting[sort_by]": "date",
    "sorting[direction]": "desc"
})

onMounted(() => {
    categoryId.value = window.location.pathname.split('/').pop();
    getData();
    getRunners();
    getResults();
})

async function getData() {
    const res = await axios.get(`/categories/${categoryId.value}.json`)
    category.value = res.data;
}

async function getRunners() {
    runnerSorting.value["category"] = categoryId.value
    const res = await axios.get('/runners.json', { params: runnerSorting.value })
    runners.value = res.data;
}

async function getResults() {
    resultSorting.value["category"] = categoryId.value
    const res = await axios.get('/results.json', { params: resultSorting.value })
    results.value = res.data;
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

function orderRunnerTable(sortKey) {
    orderTable(sortKey, runnerSorting)
    getRunners()
}

function orderResultTable(sortKey) {
    orderTable(sortKey, resultSorting)
    getResults()
}

function orderTable(sortKey, filters) {
    const isCurrentSort = filters.value["sorting[sort_by]"] === sortKey;
    const currentDir = filters.value["sorting[direction]"];

    filters.value["sorting[direction]"] = (isCurrentSort && currentDir === "asc") ? "desc" : "asc";
    filters.value["sorting[sort_by]"] = sortKey;
}
</script>
